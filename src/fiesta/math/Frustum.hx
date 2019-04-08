package fiesta.math;

class Frustum {

    public var planes:Array<Plane>;

    public function new(){
        this.planes = [];
        for(i in 0...6){
            this.planes.push(new Plane());
        }
    }

    /**
     * Copy the values from one frustum to this
     * @param  {Frustum} m the source frustum
     * @return {Frustum} this
     */
    public function copy(frustum) {
        var planes:Array<Plane> = frustum.planes;
        for(i in 0...this.planes.length){
            var plane = this.planes[i];
            plane.copy(planes[i]);
        }
        return this;
    }    

    public function clone(){
        var f = new Frustum();
        f.copy(this);
        return f;
    }

    /**
     * fromMatrix
     * @param me 
     */
    public function fromMatrix(me:Matrix4) {
        // Based on https://github.com/mrdoob/three.js/blob/dev/src/math/Frustum.js#L63

        var planes = this.planes;
        var me0 = me[0];
        var me1 = me[1];
        var me2 = me[2];
        var me3 = me[3];
        var me4 = me[4];
        var me5 = me[5];
        var me6 = me[6];
        var me7 = me[7];
        var me8 = me[8];
        var me9 = me[9];
        var me10 = me[10];
        var me11 = me[11];
        var me12 = me[12];
        var me13 = me[13];
        var me14 = me[14];
        var me15 = me[15];

        planes[0].set(me3 - me0, me7 - me4, me11 - me8, me15 - me12).normalize();
        planes[1].set(me3 + me0, me7 + me4, me11 + me8, me15 + me12).normalize();
        planes[2].set(me3 + me1, me7 + me5, me11 + me9, me15 + me13).normalize();
        planes[3].set(me3 - me1, me7 - me5, me11 - me9, me15 - me13).normalize();
        planes[4].set(me3 - me2, me7 - me6, me11 - me10, me15 - me14).normalize();
        planes[5].set(me3 + me2, me7 + me6, me11 + me10, me15 + me14).normalize();

        return this;
    }

    /**
     * Check if frustum intersects sphere
     * @param sphere 
     */
    public function intersectsSphere(sphere:Sphere){
        var planes = this.planes;
        var center:Vector4 = sphere.center;
        var negRadius = -sphere.radius;

        for (i in 0...6) {
            var distance:Float = Vector4.distance(planes[i], center);

            if (distance < negRadius) {
                return false;
            }
        }
        return true;
    }
    
}